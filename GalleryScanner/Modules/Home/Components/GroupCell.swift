import UIKit

class GroupCell: UICollectionViewCell {
    static let reuseIdentifier = "GroupCell"
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    
    override init(frame: CGRect){
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.cyan.withAlphaComponent(0.4)
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        //label's font
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        countLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        //Stack View
        let stack = UIStackView(arrangedSubviews: [titleLabel,countLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func configure(title: String, count: Int){
        titleLabel.text = title
        countLabel.text = "\(count)"
    }
}
